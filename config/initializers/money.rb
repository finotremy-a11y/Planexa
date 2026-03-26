# frozen_string_literal: true

# Keep Money behavior explicit and stable across gem upgrades.
Money.locale_backend = :i18n
Money.rounding_mode = BigDecimal::ROUND_HALF_EVEN
