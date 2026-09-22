require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "signs up a new candidate and creates a candidate profile" do
    assert_difference("User.count", 1) do
      assert_difference("Candidate.count", 1) do
        post signup_path, params: {
          user: { name: "New Candidate", email: "newcandidate@example.com", password: "password123", password_confirmation: "password123", role: "candidate" }
        }
      end
    end
    assert_redirected_to dashboard_path
  end

  test "signs up a new recruiter and creates or reuses a company" do
    assert_difference("User.count", 1) do
      assert_difference("Recruiter.count", 1) do
        assert_difference("Company.count", 1) do
          post signup_path, params: {
            user: { name: "New Recruiter", email: "newrecruiter@example.com", password: "password123", password_confirmation: "password123", role: "recruiter" },
            company_name: "SpiceJet",
            position: "Recruiter"
          }
        end
      end
    end
  end

  test "cannot self-register as admin by tampering with the role param" do
    assert_difference("User.count", 1) do
      post signup_path, params: {
        user: { name: "Sneaky", email: "sneaky@example.com", password: "password123", password_confirmation: "password123", role: "admin" }
      }
    end
    assert_equal "candidate", User.last.role
    assert_not User.last.admin?
  end

  test "does not create a user with a duplicate email" do
    assert_no_difference("User.count") do
      post signup_path, params: {
        user: { name: "Dup", email: users(:candidate_one).email, password: "password123", password_confirmation: "password123", role: "candidate" }
      }
    end
    assert_response :unprocessable_entity
  end
end
