feature 'Check description on top and botton of datetime', js: true do
  before(:each) do
    order_type = FactoryBot.create(:order_type, :support_request)
    FactoryBot.create(:order, order_type: order_type).update(code: 'ORD-36')
    user = FactoryBot.create(:user)

    signin(user.email, user.password)
    expect(page).not_to have_content 'Sign in'
    expect(page).to     have_content 'Orders list'

    click_and_wait 'ORD-36'
  end

  scenario 'should contain a top and bottom datetime descriptions' do
    parent_top = page.find('.datetime-top')
    expect(page).to have_selector "[name='topDescriptionDateTime']"
    expect(find_by_dt('description-top', parent_top).text).to eq 'Top description test'

    parent_bottom = page.find('.datetime-bottom')
    expect(page).to have_selector :css, "input[name='bottomDescriptionDatetime']"
    expect(find_by_dt('description-bottom', parent_bottom).text).to eq 'Bottom description test'
  end
end
