namespace :email_template_labels do
  desc "Create email template for delivered scan modal"
  task create: :environment do
    puts "Creating email template"

    ActiveRecord::Base.transaction do
      EmailTemplate.create({
        label: 'delivered_status_set_for_copies_to_collect',
        disabled: true,
        body_sv: <<~HEREDOC,
          Beställda kopior finns nu att hämta på [pickup_location.name_sv].

          Med vänlig hälsning

          Göteborgs universitetsbibliotek

          ["Ordernummer: " order_number]
          ["Låntagare: " name]
          ["Titel: " title]
          ["Författare: " authors]
          ["Tidskriftstitel: " journal_title]
        HEREDOC
        body_en: <<~HEREDOC,
          Ordered copies may now be collected at [pickup_location.name_en].

          Best regards

          Gothenburg University Library

          ["Ordernumber: " order_number]
          ["Patron: " name]
          ["Title: " title]
          ["Author: " authors]
          ["Journal title: " journal_title]
        HEREDOC
        subject_sv: 'Kopior att hämta',
        subject_en: 'Copies to collect'
      })
    end

    puts " All done!"
  end

  desc "Set label for email templates"
  task migrate_data: :environment do
    subject_en_to_label = {
      #'Incorrect information' => ''
      #'Not enough information' => '',
      #'Not available' => '',
      #'Not available - due' => '',
      #'For library use only' => '',
      #'Copies instead of loan?' => '',
      'Ordered item not available in any Nordic country' => 'not_available_in_nordic_country',
      #'Copies to collect' => '',
      #'Interlibrary loan' => '',
      #'Aquisition' => '',
      'Gothenburg University Library holding' => 'gub_holding',
      #'Legal deposit' => '',
      #'Reminder' => '',
      #'Article order' => '',
      #'Free electronic resource' => '',
      #'Reminder: Interlibrary loan' => '',
    }
    puts "Migrating email template data"
    EmailTemplate.all.each do |email_template|
      if subject_en_to_label.key?(email_template.subject_en)
        email_template.label = subject_en_to_label[email_template.subject_en]
      else
        email_template.label = email_template.subject_en.downcase.gsub(/\W+/) {|match| /\s+/ =~ match ? '_' : ''}
      end
      unless ['status_change_message_delivered'].include?(email_template.label)
        email_template.disabled = false
      end
      email_template.save!
    end
  end
end
