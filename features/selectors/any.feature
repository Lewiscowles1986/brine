Feature: Any Element
  Assertions can be done against any element of a structure.

  Scenario: List in response body
    When the response body is assigned:
      """
      ["a", "b", "c"]
      """
    Then the value of the response body does have any element that is equal to `a`
    And the value of the response body does not have any element that is equal to `d`

  Scenario: Nested list in response body
    When the response body is assigned:
      """
      {"letters": ["a", "b", "c"]}
      """
    Then the value of the response body child `letters` does have any element that is equal to `a`
    And the value of the response body child `letters` does not have any element that is equal to `d`

  Scenario: Map matches entries
    When the response body is assigned:
      """
      {"a": 1, "b": 2}
      """
    #Equality will match keys
    Then the value of the response body does have any element that is equal to `a`
    And the value of the response body does not have any element that is equal to `d`

  Scenario: Spread nested lists
    When the response body is assigned:
      """
      [{"val":"foo"},{"val":"bar"}]
      """
    Then the value of the response body children `..val` does have any element that is equal to `foo`
    And the value of the response body children `..val` does not have any element that is equal to `other`
