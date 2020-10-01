defmodule EctoPolymorphic.SchemaTest do
  use ExUnit.Case
  require EctoPolymorphic.Support.Repo, as: Repo

  test "handles assocs on insert" do
    sample = %Dog{name: "doguinho"}

    changeset =
      %Animal{}
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:animal, sample)

    schema = Repo.insert!(changeset)
    assoc = schema.assoc

    assert assoc.id
    assert assoc.name == "doguinho"
    assert assoc.id == schema.assoc_id
    assert assoc.inserted_at
  end
end
