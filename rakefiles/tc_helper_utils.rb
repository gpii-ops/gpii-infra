
require_relative "helper_utils"
require "test/unit"


class TestHelperUtils < Test::Unit::TestCase


  def test_yaml1
    str_a = <<~END_A
---
one:
  two: true
  three: false
END_A
    str_b = <<~END_B
---
one:
  two: false
END_B
    str_final = <<~END_F
---
one:
  two: false
  three: false
END_F
    assert_equal(str_final, InfraUtils.merge_yaml(str_a, str_b))
  end

  def test_yaml2
    str_a = <<~END_A
---
one:
  two: false
END_A
    str_b = <<~END_B
---
one:
  two:
  - three: false
END_B
    str_final = <<~END_F
---
one:
  two:
  - three: false
END_F
    assert_equal(str_final, InfraUtils.merge_yaml(str_a, str_b))
  end

  def test_yaml3
    str_a = <<~END_A
---
one:
  creationTimestamp: 2017-12-12T20:02:51Z
END_A
    str_b = <<~END_B
---
one:
  two:
  - three: false
END_B
    str_final = <<~END_F
---
one:
  creationTimestamp: 2017-12-12T20:02:51Z
  two:
  - three: false
END_F
    assert_equal(str_final, InfraUtils.merge_yaml(str_a, str_b))
  end

  def test_yaml4
    str_a = <<~END_A
one:
  two: false
---
ten:
  eleven: false
END_A
    str_b = <<~END_B
one:
  two:
  - three: false
END_B
    str_final = <<~END_F
---
one:
  two:
  - three: false
END_F
    assert_equal(str_final, InfraUtils.merge_yaml(str_a, str_b))
  end 
end
