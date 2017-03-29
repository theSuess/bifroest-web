defmodule Bifroest.Web.DomainView do
  use Bifroest.Web, :view
  alias Bifroest.Web.DomainView

  def render("index.json", %{domains: domains}) do
    %{data: render_many(domains, DomainView, "domain.json")}
  end

  def render("show.json", %{domain: domain}) do
    %{data: render_one(domain, DomainView, "domain.json")}
  end

  def render("domain.json", %{domain: domain}) do
    %{id: domain.id,
      domain: domain.domain,
      server_id: domain.server_id}
  end
end
