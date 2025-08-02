defmodule FwdCodeExerciseTest do
  use ExUnit.Case
  doctest FwdCodeExercise

  test "greets the world" do
    assert FwdCodeExercise.hello() == :world
  end
end
