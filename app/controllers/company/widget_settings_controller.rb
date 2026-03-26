# frozen_string_literal: true

# Gestion du widget de réservation embarquable dans l'espace entreprise.
# Permet à l'admin de copier le code d'intégration et de régénérer le token.
class Company::WidgetSettingsController < Company::BaseController
  # GET /company/widget
  def show
    @iframe_code       = build_iframe_code
    @script_code       = build_script_code
    @widget_url        = widget_booking_url(company_token: @company.widget_token)
    @public_page_url   = company_public_url(@company)
    @booking_qr_svg    = build_qr_svg(@public_page_url)
  end

  # POST /company/widget/regenerer-token
  def regenerate_token
    @company.regenerate_widget_token!
    redirect_to company_widget_settings_path,
      notice: "Token régénéré avec succès. Mettez à jour le code d'intégration sur votre site."
  end

  private

  def build_iframe_code
    url = widget_booking_url(company_token: @company.widget_token)
    %(<iframe src="#{url}" width="100%" height="650" frameborder="0" ) +
      %(style="border:none; max-width:680px;" title="Réservation en ligne"></iframe>)
  end

  def build_script_code
    url = widget_booking_url(company_token: @company.widget_token)
    %(<script src="#{root_url}widget.js" data-token="#{@company.widget_token}" ) +
      %(data-url="#{url}" async></script>)
  end

  def build_qr_svg(target_url)
    RQRCode::QRCode.new(target_url).as_svg(
      offset: 0,
      color: "000",
      shape_rendering: "crispEdges",
      module_size: 5,
      standalone: true,
      use_path: true
    )
  end
end
