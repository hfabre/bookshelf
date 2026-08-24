# The browse pages double as someone else's public library: same views, same
# queries, pointed at whoever owns the records. Only routes carrying a :user_id
# can point elsewhere, and only while that library is public, so adding the
# param to any other action has no effect.
module LibraryScoped
  extend ActiveSupport::Concern

  private

  def set_library_owner
    @library_owner = params[:user_id].present? ? User.find(params[:user_id]) : current_user

    return if @library_owner == current_user || @library_owner.public_library?

    redirect_to root_path, alert: t("libraries.not_public")
  end

  def library_owner
    @library_owner || current_user
  end
end
