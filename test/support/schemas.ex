defmodule Dog do
  use Ecto.Schema

  schema "dogs" do
    field(:name, :string)
    field(:age, :integer)
  end
end

defmodule Cat do
  use Ecto.Schema

  schema "cats" do
    field(:name, :string)
    field(:age, :integer)
  end
end

defmodule Animal do
  use Ecto.Schema
  use EctoPolymorphic.Schema

  schema "animals" do
    field(:owner_name, :string)

    polymorphy(:animal, [Dog, Cat])
  end
end
