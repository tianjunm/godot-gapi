extends Node

var canary_request
var http_request
var download_request

var credentials = {}
var access_token
var file

var sample_fid = "1Gg9K-QmArN6mFwtgXRc5OHu6bQUNANj4"
var cat_fid = "1jEUaj04d_eEgdws-RMDhshtAqkK69o-f"
var google_drive_base_host = "https://www.googleapis.com/drive/v2/files"

# Called when the node enters the scene tree for the first time.
func _ready():
	# ensure gapi access token works
	_check_token()

func _query_string_from_dict(dictionary):
	var query_string = ""
	for key in dictionary.keys():
		if key == "grant_type":
			query_string += "grant_type=refresh_token"
		else:
			query_string += "{key}={val}".format(
				{"key": key,
				 "val": credentials[key]})
			query_string += "&"
	print(query_string)
	return query_string

func _check_token():
	file = File.new()
	var canary_headers
	var err 

	canary_request = HTTPRequest.new()
	add_child(canary_request)
	canary_request.connect("request_completed", self, 
	"_canary_request_completed")

	file.open("credentials.json", file.READ)
	credentials = parse_json(file.get_as_text())
	file.close()

	access_token = credentials["access_token"]
	canary_headers = ["Authorization: Bearer {access_token}".format(
		{"access_token": access_token})]

	err = canary_request.request(google_drive_base_host, canary_headers, true, 
			HTTPClient.METHOD_GET)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _canary_request_completed(result, response_code, headers, body):
	print(result)
	# HACK: might be hacky, as we assume that the error is always due to 
	#       invalid (expired) access token, and that we will always get 
	#       an access token with our refresh token
	if result != OK:
		print(result)
		print("invalid access token, refreshing...")
		var refresh_request = HTTPRequest.new()
		add_child(refresh_request)
		refresh_request.connect("request_completed", self,
				"_refresh_request_completed")

		# refresh token
		var token_host = "https://oauth2.googleapis.com/token"
		var token_headers = ["Content-Type: application/x-www-form-urlencoded"]
		var data = {
			"client_id": credentials["client_id"],
			"client_secret": credentials["client_secret"],
			"refresh_token": credentials["refresh_token"],
			"grant_type": "refresh_token"
			}

		var err = canary_request.request(token_host, token_headers, true, 
				HTTPClient.METHOD_POST, _query_string_from_dict(data))
		if err != OK:
			print(err)
			print("an error occured while requesting access token.")
	else:
		print("valid access token")

func _refresh_request_completed(result, response_code, headers, body):
	var response = parse_json(body.get_string_from_utf8())
	print(response)
	access_token = response["access_token"]

	# update access token in local file
	file.open("credentials.json", file.WRITE)
	credentials["access_token"] = access_token
	file.store_string(to_json(credentials))
	file.close()

	print("successfully refreshed access token: {access_token}".format(
		{"access_token": access_token}))
	
func _on_Chest_area_shape_entered(area_id, area, area_shape, self_shape):
	print("requesting media from Google drive...")

	# Create an HTTP request node and connect its completion signal
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", self, "_http_request_completed")
	var url_template = "https://www.googleapis.com/drive/v2/files/{file_id}?alt=media"
	var url = url_template.format({"file_id": sample_fid})
	
	var headers = ["Authorization: Bearer {access_token}".format(
		{"access_token": access_token})]
	# Perform the HTTP request. The URL below returns a PNG image as of writing.
	var http_error = http_request.request(url, headers, true, 
	HTTPClient.METHOD_GET)
	if http_error != OK:
		print("An error occurred in the HTTP request.")

# Called when the HTTP request is completed.
func _http_request_completed(result, response_code, headers, body):
	print("successfully received resource from Google drive!")
	var image = Image.new()
	var image_error = image.load_png_from_buffer(body)
	if image_error != OK:
		print("An error occurred while trying to display the image.")
	
	# FIXME: temp, remove later
	image.resize(275, 141)
	var texture = ImageTexture.new()
	texture.create_from_image(image)

	# Assign to the child TextureRect node
	$Photo.texture = texture

func _on_Chest_area_shape_exited(area_id, area, area_shape, self_shape):
	$Photo.texture = null
	remove_child(http_request)
