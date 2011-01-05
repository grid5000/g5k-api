namespace :occi do  
  # This uses xmlbeans <http://xmlbeans.apache.org/> to generate the XML Schema Definition (XSD) from example XML files.
  # inst2xsd must be in your path.
  desc "Generates the XML Schema Definition for the BonFIRE OCCI namespace."
  task :xsd do
    path_to_xml_files = File.join(Rails.root, "spec", "fixtures")
    path_to_xsd_dir = File.join(Rails.root, "config", "occi")
    path_to_xsd_file = File.join(path_to_xsd_dir, "occi.xsd")
    ENV['PATH'] = [ENV['XMLBEANS_PATH'], ENV['PATH']].join(":") if ENV['XMLBEANS_PATH']
    cmd = "inst2xsd -outPrefix occi -validate -enumerations never -design ss -outDir #{path_to_xsd_dir} #{File.join(path_to_xml_files, "*.xml")}"
    puts cmd
    system cmd
  end
end