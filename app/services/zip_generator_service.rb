require "zip"

class ZipGeneratorService
  def call(books, filename_prefix)
    return { success: false, error: I18n.t("zip_generator.no_books") } if books.empty?

    zip_data = generate_zip(books)
    filename = "#{filename_prefix.parameterize}-books.zip"

    { success: true, zip_data: zip_data, filename: filename }
  end

  private

  def generate_zip(books)
    Zip::OutputStream.write_buffer do |zip|
      books.each do |book|
        if book.epub_content.present?
          zip.put_next_entry(book.filename)
          zip.write(book.epub_content)
        end
      end
    end.string
  end
end
