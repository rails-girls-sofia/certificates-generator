module Certificate
  extend self

  def generate_for(
    participant_name:,
    participant_email:,
    event_slug:,
    event_name:,
    event_date:,
    event_location:,
    target_path:
  )
    resources_path = File.dirname(__FILE__) + '/resources'
    certificate_slug = "#{event_slug}-certificate-#{Digest::MD5.hexdigest(participant_email)}"

    generic_template_path      = "#{resources_path}/template.tex"
    personalized_template_path = "#{resources_path}/#{certificate_slug}.tex"
    generated_pdf_path         = "#{resources_path}/#{certificate_slug}.pdf"
    resulting_certificate_path = "#{target_path}/#{certificate_slug}.pdf"

    variables = {
      CERTIFICATE_HOLDER_NAME: participant_name,
      EVENT_NAME: event_name,
      EVENT_DATE: event_date,
      EVENT_LOCATION: event_location,
    }

    generic_template = File.read(generic_template_path)
    personalized_certificate_content = fill_template(generic_template, variables)

    File.write(personalized_template_path, personalized_certificate_content)

    commands = [
        'cd ' + shell_escape(resources_path),
        'pdflatex -interaction=nonstopmode -output-directory ' + \
          shell_escape(resources_path) + ' ' + \
          shell_escape(personalized_template_path),
        'mkdir -p ' + shell_escape(target_path),
        'mv -f ' + shell_escape(generated_pdf_path) + ' ' + shell_escape(resulting_certificate_path),
        'rm -rf ' + shell_escape("#{resources_path}/#{certificate_slug}") + '.*',
    ]

    return false unless system(commands.join(' && '))

    resulting_certificate_path
  end

  private

  def fill_template(template_content, **variables)
    variables.each do |placeholder_name, placeholder_content|
      template_content = template_content.gsub("<#{placeholder_name}>", tex_escape(placeholder_content))
    end

    template_content
  end

  def shell_escape(text)
    Shellwords.escape text
  end

  # Escapes special chars in a text to be safely included in a LaTeX document.
  # See: http://stackoverflow.com/a/25875504/75715
  def tex_escape(text)
    replacements = {
      '&'  => '\&',
      '%'  => '\%',
      '$'  => '\$',
      '#'  => '\#',
      '_'  => '\_',
      '{'  => '\{',
      '}'  => '\}',
      '~'  => '\textasciitilde{}',
      '^'  => '\^{}',
      '\\' => '\textbackslash{}',
      '<'  => '\textless',
      '>'  => '\textgreater',
    }

    replacements.each do |search, escaped_replacement|
      text = text.gsub(search, escaped_replacement)
    end

    text
  end
end
