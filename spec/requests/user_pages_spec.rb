require 'spec_helper'

describe "UserPages" do
	
	subject {page}

	describe "profile page" do
		let(:user) {FactoryGirl.create(:user)}
		before {visit user_path(user)}

		it {should have_content(user.name)}
		it {should have_title(user.name)}
	end
	
	describe "sign up page" do
		before { visit sign_up_path }
		let(:submit) {"Create my account"}

		it {should have_content('Sign up')}
		it {should have_title(full_title('Sign up'))}

		describe "with invalid information" do
			it "should not create user" do
				expect {click_button submit}.not_to change(User,:count)
			end
			describe "after submission" do
				before {click_button submit}
				it {should have_title('Sign up')}
				it {should have_content('error')}
			end
			
		end

		describe "with valid information" do 
			before do
				fill_in "Name", with: 'Alesha'
				fill_in "Email", with: "a@a.ru"
				fill_in "Password", with: "foobar"
				fill_in "Confirm Password", with: "foobar" 
			end
			it "should create a user" do
				expect {click_button submit}.to change(User,:count).by(1)
			end
			describe "after saving user" do
				before {click_button submit}
				let(:user) {User.find_by(email: 'a@a.ru')}
				it {should have_title(user.name)}
				it {should have_link("Sign out")}
				it {should have_success_message("Welcome")}
			end
		end
	end

	describe "edit" do
		let(:user) {FactoryGirl.create(:user)}
		before do 
			sign_in user
			visit edit_user_path(user)
		end
		describe "edit page" do
			it {should have_content("Update your profile")}
			it {should have_title("Edit user")}
			it {should have_link('change', href: 'http://gravatar.com/emails')}
		end
		describe "with invalid information" do 
			before {click_button "Save changes"}
			it {should have_content("error")}
			it {should have_error_message("error")}
		end
		describe "with valid information" do
			let(:new_name)  { "New Name" }
			let(:new_email) { "new@example.com" }
			before do
				fill_in "Name",             with: new_name
				fill_in "Email",            with: new_email
				fill_in "Password",         with: user.password
				fill_in "Confirm Password", with: user.password
				click_button "Save changes"
			end

			it { should have_title(new_name) }
			it { should have_success_message() }
			it { should have_link('Sign out', href: sign_out_path) }
			specify { expect(user.reload.name).to  eq new_name }
			specify { expect(user.reload.email).to eq new_email }
		end
		describe "forbidden attributes" do 
			let(:params) do 
				{user: {admin: true, password: user.password, password_confirmation: user.password}}
			end
			before do 
				sign_in user, no_capybara: true
				patch user_path(user), params 
			end
			specify {expect(user.reload).not_to be_admin}
		end
	end

	describe "index" do
		let(:user) {FactoryGirl.create(:user)}
		before(:each) do
			sign_in user
			visit users_path
		end

		it {should have_title("All users")}
		it {should have_content("All users")}

		describe "pagination" do
			before(:all) do 
				User.delete_all
				30.times {FactoryGirl.create(:user)}
			end
			after(:all) {User.delete_all}
			it {should have_selector('div.pagination')}
			it "should list users" do 
				User.paginate(page: 1).each do |user|
					expect(page).to have_selector('li',text:user.name)
				end
			end
		end

		describe "delete links" do
			it {should_not have_link('delete')}
			describe "as admin user" do
				let(:admin) {FactoryGirl.create(:admin)}
				before do
					sign_in admin
					visit users_path
				end
				it {should have_link('delete', href: user_path(User.first))}
				it "should be able to delete user" do
					expect do 
						click_link('delete', match: :first)
					end.to change(User, :count).by(-1)
				end
				it {should_not have_link('delete', href: user_path(admin))}
			end
		end
	end
end
