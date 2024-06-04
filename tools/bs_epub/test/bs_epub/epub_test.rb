# frozen_string_literal: true

require "test_helper"

describe BsEpub::Epub do
  describe "#replace_cover!" do
    let(:path) { "test/assets/valid.epub" }
    let(:copy_path) { "test/assets/copy_valid.epub" }
    let(:cover_path) { "test/assets/new_cover.png" }

    subject { BsEpub::Epub.new(copy_path) }

    before do
      FileUtils.cp(path, copy_path)
    end

    after do
      FileUtils.rm(copy_path)
    end

    it "replace the cover" do
      _(subject.cover_node("img1")[:"media-type"]).wont_equal "images/png"

      subject.replace_cover!(cover_path)
      subject.reset
      result = subject.mt_hash

      # Keep original name but change extension if needed
      _(result[:cover_filename]).must_equal "cover.png"
      _(subject.cover_node("img1")[:"media-type"]).must_equal "image/png"
    end
  end

  describe "#update_mt!" do
    # Use a copy to avoid altering original file
    let(:path) { "test/assets/valid.epub" }
    let(:copy_path) { "test/assets/copy_valid.epub" }
    subject { BsEpub::Epub.new(copy_path) }

    before do
      FileUtils.cp(path, copy_path)
    end

    after do
      FileUtils.rm(copy_path)
    end

    let(:new_metadata) do
      {
        title: "new_title",
        author: "new author",
        language: "fr",
        date: Date.new(1994, 11, 14).iso8601,
        description: "new desc",
        publisher: "me",
        serie: "new serie",
        serie_index: 3
      }
    end

    it "updates epub metadata" do
      subject.update_mt!(new_metadata)
      subject.reset

      _(subject.mt_hash[:title]).must_equal new_metadata[:title]
      _(subject.mt_hash[:author]).must_equal new_metadata[:author]
      _(subject.mt_hash[:language]).must_equal new_metadata[:language]
      _(subject.mt_hash[:date]).must_equal new_metadata[:date]
      _(subject.mt_hash[:description]).must_equal new_metadata[:description]
      _(subject.mt_hash[:publisher]).must_equal new_metadata[:publisher]
      _(subject.mt_hash[:serie]).must_equal new_metadata[:serie]
      _(subject.mt_hash[:serie_index]).must_equal new_metadata[:serie_index]
    end

    describe "with existing calibre serie" do
      let(:path) { "test/assets/calibre_serie.epub" }
      let(:copy_path) { "test/assets/copy_calibre_serie.epub" }
      let(:new_metadata) do
        {
          serie: "new serie",
          serie_index: 10
        }
      end

      it "update serie metadata" do
        _(subject.mt_hash[:serie]).wont_equal new_metadata[:serie]

        subject.update_mt!(new_metadata)
        subject.reset
        result = subject.mt_hash

        _(result[:serie]).must_equal new_metadata[:serie]
        _(result[:serie_index]).must_equal new_metadata[:serie_index]
      end
    end

    describe "with missing mandatory metadata (title)" do
      let(:path) { "test/assets/missing_title.epub" }
      let(:copy_path) { "test/assets/copy_missing_title.epub" }
      let(:new_metadata) do
        {
          title: "new title"
        }
      end

      it "update serie metadata" do
        _(subject.mt_hash[:title]).must_be_nil

        subject.update_mt!(new_metadata)
        subject.reset
        result = subject.mt_hash

        _(result[:title]).must_equal new_metadata[:title]
      end
    end
  end

  describe "#create_container!" do
    # Use a copy to avoid altering original file
    let(:path) { "test/assets/missing_container.epub" }
    let(:copy_path) { "test/assets/copy_missing_container.epub" }
    subject { BsEpub::Epub.new(copy_path) }

    before do
      FileUtils.cp(path, copy_path)
    end

    after do
      FileUtils.rm(copy_path)
    end

    it "build the missing container file" do
      _(subject.files).wont_include BsEpub::Epub::CONTAINER_PATH
      _(subject.failure_reason).must_equal "BsEpub::ContainerMissing"

      subject.create_container!
      subject.reset

      _(subject.files).must_include BsEpub::Epub::CONTAINER_PATH
      _(subject.failure_reason).must_be_nil
      _(subject.zip.get_input_stream(BsEpub::Epub::CONTAINER_PATH).read).must_equal BsEpub::Epub.container_content("OPS/content.opf")
    end
  end

  describe "#mt_hash" do
    describe "valid epub" do
      subject { BsEpub::Epub.new("test/assets/valid.epub") }

      it "reads metadata from valid epub" do
        result = subject.mt_hash

        _(result[:title]).must_equal "Légendes espagnoles"
        _(result[:author]).must_equal "Gustavo-Adolfo Bécquer"
        _(result[:language]).must_equal "fr"
        _(result[:date]).must_equal "2024-03-20T17:07:15Z"
        _(result[:description]).must_equal "Ces contes fantastiques sont auréolés du surnaturel religieux romantique, auquel Gustavo Adolfo Bécquer apporta la touche de son lyrisme. «LES YEUX VERTS. Depuis longtemps je désirais écrire quelque chose sous ce titre. Aujourd’hui l’occasion se présente, je le mets en grandes lettres sur une feuille de papier, et aussitôt je laisse voler ma plume capricieuse. Je crois avoir vu des yeux pareils à ceux que j’ai peints dans cette légende. Est-ce en rêve ? je ne sais, mais je les ai vus. Je ne pourrai certes pas les décrire tels qu’ils étaient : lumineux, transparents, comme les gouttes de pluie qui glissent sur les feuilles des arbres, après un orage d’été. En tout cas, je compte sur l’imagination de mes lec-teurs pour comprendre ce que j’appellerai l’ébauche d’un tableau que je peindrai plus tard.»"
        _(result[:publisher]).must_equal "Ebooks libres et gratuits"
        _(result[:serie]).must_be_nil
        _(result[:serie_index]).must_be_nil
        _(result[:cover_filename]).must_equal "cover.jpg"
      end

      describe "series metadata" do
        describe "calibre series" do
          subject { BsEpub::Epub.new("test/assets/calibre_serie.epub") }

          it "get them" do
            result = subject.mt_hash

            _(result[:serie]).must_equal "calibre serie"
            _(result[:serie_index]).must_equal 1
          end
        end

        describe "epub 3.0 series" do
          subject { BsEpub::Epub.new("test/assets/epub_3_serie.epub") }

          it "get them" do
            skip "TODO"
            result = subject.mt_hash

            _(result[:serie]).must_equal "epub 3 serie"
            _(result[:serie_index]).must_equal 1
          end
        end
      end
    end

    describe "invalid epub" do
      subject { BsEpub::Epub.new("test/assets/missing_container.epub") }

      it "render default metadata" do
        result = subject.mt_hash

        _(result[:title]).must_be_nil
        _(result[:author]).must_be_nil
        _(result[:language]).must_be_nil
        _(result[:date]).must_equal Date.new(1900, 01, 01).iso8601
        _(result[:description]).must_be_nil
        _(result[:publisher]).must_be_nil
        _(result[:serie]).must_be_nil
        _(result[:serie_index]).must_be_nil
        _(result[:cover_path]).must_be_nil
      end
    end
  end
end
