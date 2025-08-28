import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["serieInput", "serieDropdown", "authorInput", "authorDropdown", "selectedAuthors"]

  connect() {
    this.selectedAuthors = new Set()
    this.selectedAuthorsTarget.querySelectorAll('input[name="author_names[]"]').forEach(input => {
      this.selectedAuthors.add(input.value)
    })

    document.addEventListener('click', this.hideDropdowns.bind(this))
  }

  disconnect() {
    document.removeEventListener('click', this.hideDropdowns.bind(this))
  }

  hideDropdowns(event) {
    if (!this.element.contains(event.target)) {
      this.serieDropdownTarget.classList.add('hidden')
      this.authorDropdownTarget.classList.add('hidden')
    }
  }

  async searchSeries() {
    const query = this.serieInputTarget.value.trim()
    if (query.length < 1) {
      this.serieDropdownTarget.classList.add('hidden')
      return
    }

    try {
      const response = await fetch(`/series?q=${encodeURIComponent(query)}`, {
        headers: {
          'Accept': 'application/json'
        }
      })
      const series = await response.json()

      let html = ''
      series.forEach(serie => {
        html += `<div class="cursor-pointer select-none relative py-2 pl-3 pr-9 hover:bg-indigo-50"
                      data-action="click->book-form#selectSerie"
                      data-serie-name="${serie.name}">
                   ${serie.name}
                 </div>`
      })

      // Create new serie if no exact match
      if (series.length === 0 || !series.some(s => s.name.toLowerCase() === query.toLowerCase())) {
        html += `<div class="cursor-pointer select-none relative py-2 pl-3 pr-9 hover:bg-indigo-50 border-t border-gray-200"
                      data-action="click->book-form#selectSerie"
                      data-serie-name="${query}">
                   <span class="text-indigo-600">Create "${query}"</span>
                 </div>`
      }

      this.serieDropdownTarget.innerHTML = html
      this.serieDropdownTarget.classList.remove('hidden')
    } catch (error) {
      console.error('Error searching series:', error)
    }
  }

  showSerieDropdown() {
    this.serieDropdownTarget.classList.remove('hidden')
  }

  selectSerie(event) {
    const serieName = event.currentTarget.dataset.serieName
    this.serieInputTarget.value = serieName
    this.serieDropdownTarget.classList.add('hidden')
  }

  // Author methods
  async searchAuthors() {
    const query = this.authorInputTarget.value.trim()
    if (query.length < 1) {
      this.authorDropdownTarget.classList.add('hidden')
      return
    }

    try {
      const response = await fetch(`/authors?q=${encodeURIComponent(query)}`, {
        headers: {
          'Accept': 'application/json'
        }
      })
      const authors = await response.json()

      let html = ''
      authors.forEach(author => {
        html += `<div class="cursor-pointer select-none relative py-2 pl-3 pr-9 hover:bg-indigo-50"
                      data-action="click->book-form#selectAuthor"
                      data-author-name="${author.name}">
                   ${author.name}
                 </div>`
      })

      // Create new author if no exact match
      if (authors.length === 0 || !authors.some(a => a.name.toLowerCase() === query.toLowerCase())) {
        html += `<div class="cursor-pointer select-none relative py-2 pl-3 pr-9 hover:bg-indigo-50 border-t border-gray-200"
                      data-action="click->book-form#selectAuthor"
                      data-author-name="${query}">
                   <span class="text-indigo-600">Create "${query}"</span>
                 </div>`
      }

      this.authorDropdownTarget.innerHTML = html
      this.authorDropdownTarget.classList.remove('hidden')
    } catch (error) {
      console.error('Error searching authors:', error)
    }
  }

  showAuthorDropdown() {
    this.authorDropdownTarget.classList.remove('hidden')
  }

  selectAuthor(event) {
    const authorName = event.currentTarget.dataset.authorName
    this.addAuthor(authorName)
    this.authorInputTarget.value = ''
    this.authorDropdownTarget.classList.add('hidden')
  }

  addAuthor(authorName) {
    if (this.selectedAuthors.has(authorName)) {
      return
    }

    this.selectedAuthors.add(authorName)

    const authorElement = document.createElement('div')
    authorElement.className = 'flex items-center justify-between bg-gray-50 px-3 py-2 rounded-md'
    authorElement.innerHTML = `
      <span>${authorName}</span>
      <button type="button"
              data-action="click->book-form#removeAuthor"
              data-author-name="${authorName}"
              class="text-red-600 hover:text-red-700">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
        </svg>
      </button>
      <input type="hidden" name="book[author_names][]" value="${authorName}">
    `

    this.selectedAuthorsTarget.appendChild(authorElement)
  }

  removeAuthor(event) {
    const authorName = event.currentTarget.dataset.authorName
    this.selectedAuthors.delete(authorName)
    event.currentTarget.closest('div').remove()
  }

  handleAuthorKeydown(event) {
    if (event.key === 'Enter') {
      event.preventDefault()
      const query = this.authorInputTarget.value.trim()
      if (query.length > 0) {
        this.addAuthor(query)
        this.authorInputTarget.value = ''
        this.authorDropdownTarget.classList.add('hidden')
      }
    }
  }

  refreshCoverPreview() {
    const coverImg = this.element.querySelector('img[alt="Current cover"]')
    if (coverImg) {
      // Force reload by changing the src
      const currentSrc = coverImg.src
      coverImg.src = ''
      coverImg.src = currentSrc
    }
  }

  handleCoverChange(event) {
    const file = event.target.files[0]
    if (file) {
      const reader = new FileReader()
      reader.onload = (e) => {
        const coverImg = this.element.querySelector('img[alt="Current cover"]')
        if (coverImg) {
          coverImg.src = e.target.result
        }
      }
      reader.readAsDataURL(file)
    }
  }
}
