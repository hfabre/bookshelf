# Preview all emails at http://localhost:3000/rails/mailers/epub_processing_mailer
class EpubProcessingMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/epub_processing_mailer/failed
  def failed
    EpubProcessingMailer.failed(Book.take)
  end
end
