
module IdentityMatching
  class PatientMatching < Inferno::TestGroup

    title 'Patient Matching Tests'
    description 'Execute a $match operation at /Patient/$match endpoint on a Master Patient Index (MPI). '
    id :patient_matching

	test do
	  id :end_user_authorization
	  title 'Patient-initiated workflows SHALL require end-user authorization'
	  description <<~DESC
		If a client or fullstack application allows any patient to make $match queries for themselves, then
		they must have explicit authorization by the subject patient for that information (i.e: OAuth2).
	  DESC

	  run do
		  info "This test is an automatic pass, please see ABOUT."
		  pass
	  end
	end

	test do
	  id :transmitting_identity
	  title 'The transmitter of identity attributes with an asserted assurance level SHALL verify the attributes at that assurance level or be consistent with other evidence'
	  description <<~DESC
		Any software can only share identity attributes (i.e: full name, date of birth, etc.) with third parties where Personally Identifiable Infomration (PII) sharing is permited.
		When it does so the transmitting software may assert an identity assurance level (IAL) with the attributes. If it does then the transmitter must verify the information sent
		to the level as required by that IAL (see Identity Assurance section or NIST 800 63) or send consistent information. Examples of sharing identity attributes include a UDAP
		assertion objects and $match requests.
	  DESC

	  run do
		info "This test is an automatic pass, please see ABOUT."
		pass
	  end
	end

	## TODO
	# Insert Code here for patient matching tests
	# Enable "Manual Stewardship" Info
	# Reveal presence/lack of manual stewardship Info
	# Use probabilitic scoring Info
	# Model common correlations such as families Info

  end
end
