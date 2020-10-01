defmodule EctoPolymorphic.Schema do
  @moduledoc """

  """
  alias EctoPolymorphic.Type, as: PolymorphicType

  defmacro __using__(_opts) do
    quote do
      import EctoPolymorphic.Schema
    end
  end

  defmacro polymorphy(name, types) do
    check_polymorphic!(types)

    {:module, module, _, _} = PolymorphicType.generate_ecto_type(__CALLER__.module, name, types)

    quote do
      unquote(__MODULE__).__belongs_to__(
        __MODULE__,
        unquote(name),
        types: unquote(types)
      )

      field(unquote(:"#{name}_type"), unquote(module))
    end
  end

  def check_polymorphic!(types) when is_list(types), do: :ok

  def check_polymorphic!(_) do
    raise """
    Polymorphic relationships require knowing all the possible types at compile time. Pass them in as
    a keyword list mapping the expected database value to the Ecto Schema
    """
  end

  @valid_belongs_to_options [
    :foreign_key,
    :references,
    :define_field,
    :type,
    :types,
    :on_replace,
    :defaults,
    :primary_key,
    :polymorphic
  ]

  def __belongs_to__(mod, name, opts) do
    check_options!(opts, @valid_belongs_to_options, "belongs_to/3")

    opts = Keyword.put_new(opts, :foreign_key, :"#{name}_id")
    foreign_key_type = opts[:type] || Module.get_attribute(mod, :foreign_key_type)

    if name == Keyword.get(opts, :foreign_key) do
      raise ArgumentError,
            "foreign_key #{inspect(name)} must be distinct from corresponding association name"
    end

    if Keyword.get(opts, :define_field, true) do
      Ecto.Schema.__field__(mod, opts[:foreign_key], foreign_key_type, opts)
    end

    struct = association(mod, :one, name, EctoPolymorphic.Association, opts)
    Module.put_attribute(mod, :changeset_fields, {name, {:assoc, struct}})
  end

  defp check_options!(opts, valid, fun_arity) do
    case Enum.find(opts, fn {k, _} -> not (k in valid) end) do
      {k, _} ->
        raise ArgumentError, "invalid option #{inspect(k)} for #{fun_arity}"

      nil ->
        :ok
    end
  end

  defp association(mod, cardinality, name, association, opts) do
    not_loaded = %Ecto.Association.NotLoaded{
      __owner__: mod,
      __field__: name,
      __cardinality__: cardinality
    }

    put_struct_field(mod, name, not_loaded)
    opts = [cardinality: cardinality] ++ opts
    struct = association.struct(mod, name, opts)
    Module.put_attribute(mod, :ecto_assocs, {name, struct})

    struct
  end

  defp put_struct_field(mod, name, assoc) do
    fields = Module.get_attribute(mod, :struct_fields)

    if List.keyfind(fields, name, 0) do
      raise ArgumentError, "field/association #{inspect(name)} is already set on schema"
    end

    Module.put_attribute(mod, :struct_fields, {name, assoc})
  end
end
