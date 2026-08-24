# The browse pages double as someone else's public library: same views, same
# queries, pointed at whoever owns the records. Only reading is scoped this way,
# and only to a public library, so the worst a hand-written :user_id can do is
# reach a page the library routes already serve.
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
