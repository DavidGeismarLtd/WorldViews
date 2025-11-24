# frozen_string_literal: true

# Pagy initializer file (9.0.9)
# Customize only what you really need and notice that the core Pagy works also without any of the following lines.
# Should you just cherry pick part of this file, please maintain the require-order of the extras

# Pagy DEFAULT Variables
# See https://ddnexus.github.io/pagy/docs/api/pagy#variables
Pagy::DEFAULT[:items] = 5  # items per page
Pagy::DEFAULT[:size]  = [ 1, 4, 4, 1 ]  # nav bar pagination

# Better user experience handled automatically
require "pagy/extras/overflow"
Pagy::DEFAULT[:overflow] = :last_page

# Turbo support for infinite scroll
require "pagy/extras/countless"

