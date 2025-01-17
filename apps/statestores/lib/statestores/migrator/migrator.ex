defmodule Statestores.Migrator do
  import Statestores.Util, only: [load_app: 0, load_repo: 0]

  @spec migrate :: {:ok, any, any}
  def migrate do
    load_app()
    repo = load_repo()

    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
  end

  @spec rollback(any, any) :: {:ok, any, any}
  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end
end
