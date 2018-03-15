defmodule MutationTest do
  @moduledoc """
  """
  use ExUnit.Case
  require Logger
  import ExDgraph.TestHelper

  @map_insert_mutation %{
    name: "Alice",
    identifier: "alice_json",
    friends: [
      %{
        name: "Betty"
      }
    ]
  }

  @map_insert_check_query """
    {
        people(func: allofterms(identifier, "alice_json"))
        {
          uid
          name
          friends
          {
            name,
            uid
          }
        }
    }
  """

  setup do
    conn = ExDgraph.conn()
    drop_all()
    import_starwars_sample()

    on_exit(fn ->
      # close channel ?
      :ok
    end)

    [conn: conn]
  end

  test "mutation/2 returns {:ok, mutation_msg} for correct mutation", %{conn: conn} do
    {status, mutation_msg} = ExDgraph.mutation(conn, starwars_creation_mutation())
    assert status == :ok
    assert mutation_msg.context.aborted == false
  end

  test "mutation/2 returns {:error, error} for incorrect mutation", %{conn: conn} do
    {status, error} = ExDgraph.mutation(conn, "wrong")
    assert status == :error
    assert error[:code] == 2
  end

  # TODO: Take care of updates via uid
  test "insert_map/2 returns {:ok, mutation_msg} for correct mutation", %{conn: conn} do
    {status, mutation_msg} = ExDgraph.insert_map(conn, @map_insert_mutation)
    assert status == :ok
    assert mutation_msg.context.aborted == false
    query_msg = ExDgraph.Query.query!(conn, @map_insert_check_query)
    res = query_msg.result
    people = res["people"]
    alice = List.first(people)
    assert alice["name"] == "Alice"
    betty = List.first(alice["friends"])
    assert betty["name"] == "Betty"
  end

  test "insert_map!/2 returns mutation_message", %{conn: conn} do
    mutation_msg = ExDgraph.insert_map!(conn, @map_insert_mutation)
    assert mutation_msg.context.aborted == false
    query_msg = ExDgraph.Query.query!(conn, @map_insert_check_query)
    res = query_msg.result
    people = res["people"]
    alice = List.first(people)
    assert alice["name"] == "Alice"
    betty = List.first(alice["friends"])
    assert betty["name"] == "Betty"
  end

  test "insert_map/2 returns result with uids", %{conn: conn} do
    {status, mutation_msg} = ExDgraph.insert_map(conn, @map_insert_mutation)
    IO.inspect(mutation_msg)
    assert status == :ok
    assert is_map(mutation_msg.result)
    mutation_alice = mutation_msg.result
    mutation_betty = List.first(mutation_alice[:friends])
    query_msg = ExDgraph.Query.query!(conn, @map_insert_check_query)
    query_people = query_msg.result["people"]
    query_alice = List.first(query_people)
    query_betty = List.first(query_alice["friends"])
    assert mutation_alice[:uid] == query_alice["uid"]
    assert mutation_betty[:uid] == query_betty["uid"]
  end

  test "insert_map!/2 returns result with uids", %{conn: conn} do
    mutation_msg = ExDgraph.insert_map!(conn, @map_insert_mutation)
    assert is_map(mutation_msg.result)
    mutation_alice = mutation_msg.result
    mutation_betty = List.first(mutation_alice[:friends])
    query_msg = ExDgraph.Query.query!(conn, @map_insert_check_query)
    query_people = query_msg.result["people"]
    query_alice = List.first(query_people)
    query_betty = List.first(query_alice["friends"])
    assert mutation_alice[:uid] == query_alice["uid"]
    assert mutation_betty[:uid] == query_betty["uid"]
  end
end
