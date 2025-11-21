class ProfilesController < ApplicationController
  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if @user.authenticate(params[:current_password])
      if @user.update(user_params)
        redirect_to edit_profile_path, notice: "Password updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    else
      @user.errors.add(:current_password, "is incorrect")
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
