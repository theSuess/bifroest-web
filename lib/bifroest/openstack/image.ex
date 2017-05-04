defmodule Bifroest.Openstack.Image do
  defmodule Image do
    defstruct [:id, :name, :description]
  end

  import Bifroest.Openstack.Base

  @url Application.get_env(:bifroest,:openstack_image_url)

  def get_images() do
    case HTTPoison.get(@url <> "/images",headers()) do
      {:ok, %HTTPoison.Response{body: body}} ->
        {:ok, %{"images" => images}} = body |> Poison.decode(as: %{"images" => [%Image{}]})
        {:ok, images}
      _ -> {:error, "Unable to get flavors"}
    end
  end
end
