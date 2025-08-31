package data

import(
	"movienode.atharva.net/internal/validator"
)

type Filters struct {
	Page int
	PageSize int
	Sort string
	SortSafeList []string
}

func ValidateFilters(v *validator.Validator, f Filters) {
	v.Check(f.Page <= 10_000_000, "page", "must be maximum of 10 million")
	v.Check(f.Page > 0, "page", "must be greater than zero")
	v.Check(f.PageSize  <= 100, "page_size", "must be must be maximum of 100")
	v.Check(f.PageSize > 0, "page_size", "must be greater than 0")
	v.Check(validator.In(f.Sort, f.SortSafeList...), "sort", "invalid sort value")
}
