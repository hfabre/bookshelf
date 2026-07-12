class EpubProcessingMailer < ApplicationMailer
  def failed(book)
    @book = book
    @title = book.title.presence || book.filename
    mail to: book.user.email_address, subject: default_i18n_subject(title: @title)
  end
end
