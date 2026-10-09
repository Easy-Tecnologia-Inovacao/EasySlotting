const loadedFonts = new Set<string>()

const ALLOWED_FONT_FAMILIES = new Set([
  'Inter', 'Plus Jakarta Sans', 'Poppins', 'Roboto', 'Open Sans',
  'Lato', 'Montserrat', 'Nunito', 'Work Sans', 'Rubik',
  'Playfair Display', 'Merriweather', 'Lora', 'EB Garamond', 'Bitter', 'Libre Baskerville',
  'Bebas Neue', 'Anton', 'Fredoka',
  'Pacifico', 'Dancing Script', 'Caveat',
  'Fira Code', 'JetBrains Mono', 'Space Mono'
])

function sanitizeFontName(font: string): string {
  return font.replace(/[^a-zA-Z0-9\s\-]/g, '').slice(0, 50)
}

function isValidFont(font: string): boolean {
  return ALLOWED_FONT_FAMILIES.has(sanitizeFontName(font))
}

export function loadGoogleFont(fontFamily: string, weights: string = '400;500;600;700'): void {
  const clean = sanitizeFontName(fontFamily)
  if (!clean || loadedFonts.has(clean)) return

  const link = document.createElement('link')
  link.rel = 'stylesheet'
  link.href = `https://fonts.googleapis.com/css2?family=${clean.replace(/\s+/g, '+')}:wght@${weights}&display=swap`
  link.crossOrigin = 'anonymous'
  document.head.appendChild(link)
  loadedFonts.add(clean)
}

export function loadFontIfValid(fontFamily: string): boolean {
  const name = sanitizeFontName(fontFamily)
  if (!name || loadedFonts.has(name)) return false
  loadGoogleFont(name)
  return true
}

export { isValidFont, sanitizeFontName, ALLOWED_FONT_FAMILIES }
