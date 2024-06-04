# BsEpub

This is a set of ruby scripts mean to be used my the bookshelf web application.
For now it includes :

- Getting metadata from an epub
- Updating medata of an epub
- Replacing cover of an epub
- Getting cover from an epub

To keep things simple :

- I only handle metadata which are important
- IO is based on json only

```ruby
{
  title: "string",
  author: "string",
  language: "string",
  date: Date.new(1900, 01, 01).iso8601,
  description: "string",
  publisher: "string",
  serie: "string",
  serie_index: 0.0,
  cover_filename: "Name inside the zipfile"
}
```

Series metadata are based on calibre `cablibre:series` custom meta. I plan to support epub v3 also.
When I will do, updating a serie will update (or create) both calibre meta and epub v3.

# TODO

The missing thing I'm not handling for now but I do want to are :

- Epub v3
- Metadata which can be an array (at least for authors which is important to me)
