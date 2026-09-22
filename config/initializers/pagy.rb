require "pagy/extras/bootstrap"
require "pagy/extras/overflow"

Pagy::DEFAULT[:limit] = 12
Pagy::DEFAULT[:size] = 7
# A live search that narrows results can leave a stale ?page=N in the URL
# pointing past the new last page; clamp instead of raising Pagy::OverflowError.
Pagy::DEFAULT[:overflow] = :last_page
