class Company::ProfilesController < Company::BaseController
  ALLOWED_LOGO_CONTENT_TYPES = %w[image/jpeg image/png image/webp image/gif].freeze
  MAX_LOGO_SIZE_BYTES = 5.megabytes

  def show; end
  def edit; end

  def update
    @company.assign_attributes(company_params)

    if handle_logo_update && @company.save
      MedicalAuditLogger.log!(
        company: @company,
        user: current_user,
        action: "medical_profile_updated",
        record: @company,
        metadata: {
          changed_fields: @company.saved_changes.keys & %w[
            professional_category
            health_specialty
            convention_sector
            teleconsultation_enabled
            accessibility_info
            practical_info
            cancellation_policy
          ]
        }
      )
      redirect_to company_profile_path, notice: "Profil mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def handle_logo_update
    return remove_logo! if remove_logo_param?

    logo_file = params.dig(:company, :logo)
    return true if logo_file.blank?

    unless valid_logo_file?(logo_file)
      return false
    end

    upload_result = Cloudinary::Uploader.upload(
      logo_file.path,
      folder: "planexa/companies",
      resource_type: :image
    )

    @company.logo_public_id = upload_result["public_id"]
    true
  rescue StandardError
    @company.errors.add(:base, "Impossible de televerser le logo pour le moment.")
    false
  end

  def valid_logo_file?(logo_file)
    unless ALLOWED_LOGO_CONTENT_TYPES.include?(logo_file.content_type)
      @company.errors.add(:base, "Format de logo non supporte. Utilisez JPG, PNG, WEBP ou GIF.")
      return false
    end

    if logo_file.size.to_i > MAX_LOGO_SIZE_BYTES
      @company.errors.add(:base, "Le logo ne doit pas depasser 5 MB.")
      return false
    end

    true
  end

  def remove_logo_param?
    params.dig(:company, :remove_logo) == "1"
  end

  def remove_logo!
    @company.logo_public_id = nil
    true
  end

  def company_params
    params.require(:company).permit(
      :name, :siret, :address, :city, :zip_code,
      :phone, :description, :website,
      :professional_category, :health_specialty,
      :convention_sector, :teleconsultation_enabled,
      :accessibility_info, :practical_info, :cancellation_policy
    )
  end
end
