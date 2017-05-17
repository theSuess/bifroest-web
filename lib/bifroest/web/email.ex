defmodule Bifroest.Web.Email do
  use Bamboo.Phoenix, view: Bifroest.Web.EmailView

  def password_email(email_address, password) do
    new_email
    |> to(email_address)
    |> from("bifroest@htl-ottakring.ac.at")
    |> subject("Your OpenStack Credentials")
    |> put_html_layout({Bifroest.Web.LayoutView, "email.html"})
    |> render("password.html", username: email_address, password: password)
  end

  def server_email(email_address, name, password, server_id) do
    new_email
    |> to(email_address)
    |> from("bifroest@htl-ottakring.ac.at")
    |> subject("Your deployment has been successfull!")
    |> put_html_layout({Bifroest.Web.LayoutView, "email.html"})
    |> render("server.html", name: name, admin_password: password, server_id: server_id)
  end
end
