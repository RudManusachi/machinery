defmodule MachineryTest.ResourceControllerTest do
  use ExUnit.Case, async: false
  use Plug.Test

  alias MachineryTest.TestStateMachine
  alias MachineryTest.TestRepo
  alias MachineryTest.Helper

  setup_all do
    Helper.mahcinery_interface()
  end

  @tag :capture_log
  test "index/2 should assign a state map to the conn with all states declared" do
    conn = Machinery.Plug.call(conn(:get, "/"), "/")
    assert TestStateMachine._machinery_states() == Enum.map(conn.assigns.states, &(&1.name))
  end

  @tag :capture_log
  test "index/2 should assign a list with the resources in each state" do
    conn = Machinery.Plug.call(conn(:get, "/"), "/")
    resoruces_for_each_state = Enum.map(conn.assigns.states, fn(_x) ->
      TestRepo.all(nil)
    end)
    assert resoruces_for_each_state == Enum.map(conn.assigns.states, &(&1.resources))
  end

  @tag :capture_log
  test "index/2 should assign a friendly name for the resource using the state machine" do
    conn = Machinery.Plug.call(conn(:get, "/"), "/")
    assert conn.assigns.friendly_module_name == "TestStruct"
  end

  @tag :capture_log
  test "A request to an unexpect route should still result into an error" do
    assert_raise Phoenix.Router.NoRouteError, fn() ->
      Machinery.Plug.call(conn(:get, "/wrong-route"), "/")
    end
  end

  @tag :capture_log
  test "index/2 should also respond to /api requests returning json" do
    state = List.first(TestStateMachine._machinery_states())
    page = 1
    conn = Machinery.Plug.call(conn(:get, "/machinery/api/#{state}/resources/#{page}"), [])
    resources_maps = Enum.map(TestRepo.all(nil), &stringify_keys/1)
    assert Poison.decode!(conn.resp_body) == resources_maps
  end

  @tag :capture_log
  test "index/2 api should paginate correctly" do
    state = List.first(TestStateMachine._machinery_states())
    page = 2
    conn = Machinery.Plug.call(conn(:get, "/machinery/api/#{state}/resources/#{page}"), [])
    assert Poison.decode!(conn.resp_body) == []
  end

  defp stringify_keys(nil), do: nil
  defp stringify_keys(%{} = map) do
    map
    |> Enum.map(fn {k, v} -> {Atom.to_string(k), v} end)
    |> Enum.into(%{})
  end
end