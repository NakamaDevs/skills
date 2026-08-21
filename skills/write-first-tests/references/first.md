# FIRST reference

Microsoft's [unit-testing best practices](https://learn.microsoft.com/en-us/dotnet/core/testing/unit-testing-best-practices) describes fast, repeatable, and timely tests and emphasizes isolated, readable tests. Cornell's [testing and debugging notes](https://www.cs.cornell.edu/courses/cs3110/2014fa/recitations/2/rec02.html) state the complete FIRST set: fast, independent, repeatable, self-verifying, and timely.

## Failure smells

- **Fast:** routine local tests need seconds per case or download dependencies.
- **Independent:** a case passes only after another case or shares a mutable database/profile.
- **Repeatable:** results depend on wall time, global randomness, network, machine state, or test order.
- **Self-validating:** a human must inspect a screenshot or log to decide success.
- **Timely:** production behavior exists without a characterizing test, or the test cannot fail for the intended reason.

Screenshots, traces, and logs support diagnosis. Pair them with deterministic assertions.
