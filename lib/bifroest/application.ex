defmodule Bifroest.Application do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(Bifroest.Repo, []),
      # Start the endpoint when the application starts
      supervisor(Bifroest.Web.Endpoint, []),
      # Start the openstack process registry
      supervisor(Registry, [:unique, :os_process_registry]),
      # Start your own worker by calling: Bifroest.Worker.start_link(arg1, arg2, arg3)
      # worker(Bifroest.Worker, [arg1, arg2, arg3]),
      worker(Bifroest.Openstack.Registry, []),
      worker(Bifroest.Loadbalancer, [])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Bifroest.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
