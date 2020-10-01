defmodule EctoPolymorphic.Association do
  @moduledoc """

  """

  @behaviour Ecto.Changeset.Relation
  import Ecto.Query

  @on_replace_opts [:raise, :mark_as_invalid, :delete, :nilify, :update]
  defstruct [
    :field,
    :owner,
    :owner_key,
    :related_key,
    :type_field,
    :on_cast,
    :key_field,
    :on_replace,
    defaults: [],
    cardinality: :one,
    relationship: :parent,
    unique: true,
    assoc_query_receives_structs: true,
    queryable: nil
  ]

  @doc false
  def struct(module, name, opts) do
    on_replace = Keyword.get(opts, :on_replace, :raise)

    unless on_replace in @on_replace_opts do
      raise ArgumentError,
            "invalid `:on_replace` option for #{inspect(name)}. " <>
              "The only valid options are: " <>
              Enum.map_join(@on_replace_opts, ", ", &"`#{inspect(&1)}`")
    end

    %__MODULE__{
      field: name,
      owner: module,
      owner_key: Keyword.fetch!(opts, :foreign_key),
      key_field: :"#{name}_id",
      type_field: :"#{name}_type",
      on_replace: on_replace,
      defaults: opts[:defaults] || [],
      queryable: default_queryable(opts[:types])
    }
  end

  @doc false
  defp default_queryable([{_db_value, module} | _]), do: module
  defp default_queryable([module | _]), do: module

  def joins_query(_) do
    raise """
    #{__MODULE__} Join Error: Polymorphic associations cannot be joined with! Convert to a concrete table.
    Perhaps you meant to use preload instead?
    """
  end

  def assoc_query(_, _, _) do
    raise """
    #{__MODULE__} Association Error: Polymorphic associations cannot return an association query! Convert to a concrete table.
    Perhaps you meant to use preload instead?
    """
  end

  def preload(_refl, _repo, _query, []), do: []

  def preload(
        %{type_field: type_field, key_field: key_field, owner: mod} = refl,
        repo,
        base_query,
        [%mod{} | _] = structs,
        opts
      ) do
    structs
    |> Enum.map(&Map.fetch!(&1, type_field))
    |> Enum.uniq()
    |> Enum.flat_map(fn type ->
      values =
        Enum.filter(structs, &(Map.fetch!(&1, type_field) == type))
        |> Enum.map(&Map.fetch!(&1, key_field))
        |> Enum.uniq()

      [related_key] = type.__schema__(:primary_key)

      query = from(x in type, where: field(x, ^related_key) in ^values)
      query = %{query | select: base_query.select, prefix: base_query.prefix}

      query = Ecto.Repo.Preloader.normalize(query, refl, {0, related_key})
      repo.all(query, opts)
    end)
  end

  def preload_info(%{type_field: _type_field, owner: _mod} = refl) do
    {:assoc, refl, nil}
  end

  @doc false
  def after_compile_validation(_assoc, _env) do
    :ok
  end

  @doc false
  defdelegate build(refl, struct, attributes), to: Ecto.Association.BelongsTo
  defdelegate build(assoc, owner), to: Ecto.Association.BelongsTo

  defdelegate on_repo_change(data, parent_changeset, changeset, adapter, opts),
    to: Ecto.Association.BelongsTo
end
