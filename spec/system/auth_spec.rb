require 'rails_helper'

RSpec.describe 'Authentication', type: :system do
  describe 'creating an account' do
    it 'allows a new user to sign up with valid credentials' do
      visit new_user_registration_path

      fill_in 'Email', with: 'newuser@example.com'
      fill_in 'Password', with: 'password123'
      fill_in 'Password confirmation', with: 'password123'
      click_button 'Sign up'

      expect(page).to have_content('Welcome! You have signed up successfully.')
    end

    it 'shows errors when passwords do not match' do
      visit new_user_registration_path

      fill_in 'Email', with: 'newuser@example.com'
      fill_in 'Password', with: 'password123'
      fill_in 'Password confirmation', with: 'different_password'
      click_button 'Sign up'

      expect(page).to have_content("Password confirmation doesn't match Password")
    end

    it 'shows an error when the email is already taken' do
      create(:user, email: 'existing@example.com')

      visit new_user_registration_path
      fill_in 'Email', with: 'existing@example.com'
      fill_in 'Password', with: 'password123'
      fill_in 'Password confirmation', with: 'password123'
      click_button 'Sign up'

      expect(page).to have_content('Email has already been taken')
    end
  end

  describe 'signing in' do
    let!(:user) { create(:user, email: 'test@example.com', password: 'password123') }

    it 'allows an existing user to sign in with correct credentials' do
      visit new_user_session_path

      fill_in 'Email', with: 'test@example.com'
      fill_in 'Password', with: 'password123'
      click_button 'Log in'

      expect(page).to have_current_path(root_path)
    end

    it 'shows an error when credentials are invalid' do
      visit new_user_session_path

      fill_in 'Email', with: 'test@example.com'
      fill_in 'Password', with: 'wrong_password'
      click_button 'Log in'

      expect(page).to have_content('Invalid Email or password')
    end
  end
end
