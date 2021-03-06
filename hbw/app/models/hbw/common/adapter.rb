module HBW
  module Common
    class Adapter
      include HBW::Inject[:api, :config]

      def entity_code_key(entity_class)
        config[:entities].fetch(entity_class)[:entity_code_key]
      end

      # TODO: cache it until new user is added
      def users
        HBW::BPMUser.fetch_all
      end

      def user_exist?(user_email)
        user = HBW::BPMUser.with_connection(api) do
          HBW::BPMUser.fetch(user_email)
        end

        !user.nil?
      end

      def users_lookup(pattern)
        d_pattern = pattern.mb_chars.downcase.to_s

        users.select do |user|
          user.values.find { |v| v.mb_chars.downcase.include?(d_pattern) }
        end
      end

      def active_process_instances(_, _)
        raise NotImplementedError
      end

      def submit(_, _, _, _)
        raise NotImplementedError
      end

      # TODO: How to distinguish between running process instance and done
      # TODO: Think of suspended process instances
      def bp_running?(entity_code, entity_class)
        active_process_instances(entity_code, entity_class).present?
      end

      def get_variables(_, _, _, _)
        raise NotImplementedError
      end

      def start_process(bp_code,
                        user_email,
                        entity_code,
                        entity_class,
                        initial_variables)
        user = HBW::BPMUser.with_connection(api) do
          HBW::BPMUser.fetch(user_email)
        end
        return false unless user

        p_def = process_definition_for_key_like(bp_code)
        return false unless p_def

        variables = get_variables(user, entity_class, entity_code, initial_variables)

        business_key = [entity_class, entity_code].join('_')

        response = start_process_response(p_def['id'], variables, business_key)
        response.status == 201
      end

      def task_list(email, entity_class)
        HBW::Task.with_connection(api) do
          tasks = HBW::Task.list(email, entity_class)

          tasks
        end
      end

      def claim_task(email, task_id)
        HBW::Task.with_connection(api) do
          HBW::Task.claim_task(email, task_id)
        end
      end

      def form(task_id, entity_class)
        HBW::Form.with_connection(api) do
          HBW::Form.fetch(task_id, entity_class)
        end
      end

      def get_forms_for_task_list(tasks)
        HBW::Task.with_connection(api) do
          forms = JSON.parse(tasks).map do |task|
            {form_fields: form(task['task_id'], task['entity_class']),
             task_id:     task['task_id']}
          end

          forms
        end
      end

      def get_form_by_task_id(task_id)
        HBW::Form.with_connection(api) do
          HBW::Form.get_form_by_task_id(task_id)
        end
      end

      def get_task_by_id(task_id)
        HBW::Task.with_connection(api) do
          HBW::Task.get_task_by_id(task_id)
        end
      end

      def get_task_with_form(task_id, entity_class, cache_key)
        HBW::Task.with_connection(api) do
          HBW::Task.get_task_with_form(task_id, entity_class, cache_key)
        end
      end

      def process_instance_from(proc_inst_id)
        response = api.get("runtime/process-instances/#{proc_inst_id}")
        response.body if response.status == 200
      end
    end
  end
end
