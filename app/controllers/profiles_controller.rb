class ProfilesController < ApplicationController
  def edit
    @user = current_user
  end

  def update
    @user = current_user

    # If password is blank, exclude it from the update
    if params[:user][:password].blank?
      update_params = user_params.except(:password, :password_confirmation)
    else
      update_params = user_params
    end

    if @user.update(update_params)
      redirect_to edit_profile_path, notice: t(".notice")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:password, :password_confirmation, :public_library)
  end
end
