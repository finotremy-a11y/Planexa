# frozen_string_literal: true

# Prawn built-in AFM fonts don't fully support UTF-8; this warning is noisy in tests.
Prawn::Fonts::AFM.hide_m17n_warning = true if defined?(Prawn::Fonts::AFM)
