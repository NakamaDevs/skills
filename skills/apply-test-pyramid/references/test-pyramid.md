# Test-pyramid reference

## Source position

- Martin Fowler's [Practical Test Pyramid](https://martinfowler.com/articles/practical-test-pyramid.html) treats the pyramid as an economic heuristic: integration tests prove real collaborations that unit tests cannot, while broad-stack E2E tests are slow, costly, and prone to false failures.
- Fowler recommends keeping E2E coverage to the minimum set of high-value user journeys and leaving edge cases to lower layers.
- A browser test is not automatically end-to-end. A UI can be tested against controlled backends; reserve the E2E label for the complete integrated path.

## Application rule

Do not target a universal percentage. Let failure risk, execution cost, and architectural seams set the shape. A service with substantial wiring may need more integration coverage; it still needs fast focused tests and very few broad-stack journeys.
