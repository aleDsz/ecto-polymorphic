defmodule EctoPolymorphic.Type do
  @moduledoc false

  @doc false
  def generate_ecto_type(module, name, mapping) do
    custom_name =
      to_string(name)
      |> String.capitalize()
      |> Kernel.<>("PolymorphicType")

    module =
      module
      |> Module.concat(:"#{custom_name}")

    quoted =
      quote bind_quoted: [module: module, mapping: mapping] do
        use Ecto.Type

        def type(), do: :string

        for {db_value, schema} <- mapping do
          def cast(unquote(to_string(db_value))) do
            {:ok, unquote(schema)}
          end
        end

        def cast(_), do: :error

        def load(type), do: cast(type)

        for {db_value, schema} <- mapping do
          def dump(unquote(schema)) do
            {:ok, unquote(to_string(db_value))}
          end
        end

        def dump(_), do: :error
      end

    Module.create(module, quoted, Macro.Env.location(__ENV__))
  end
end
