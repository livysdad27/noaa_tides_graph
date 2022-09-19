load("render.star", "render")
load("math.star", "math")
load("time.star", "time")
load("http.star", "http")
load("encoding/json.star", "json")

# Call both the full data set for the station for the day and make a separate call to the hilo form.  Since we're cacheing eventually two calls isn't bad.
NOAA_API_URL_GRAPH="https://api.tidesandcurrents.noaa.gov/api/prod/datagetter?date=today&station=9446807&product=predictions&datum=MLLW&time_zone=lst_ldt&units=english&format=json"
NOAA_API_URL_HILO="https://api.tidesandcurrents.noaa.gov/api/prod/datagetter?date=today&station=9446807&product=predictions&datum=MLLW&time_zone=lst_ldt&units=english&format=json&interval=hilo"

def main(config):
    timezone = config.get("timezone") or "America/Los_Angeles"
    now = time.now().in_location(timezone)
    
    # GET MUH DATA
    resp_graph = http.get(NOAA_API_URL_GRAPH)
    resp_hilo = http.get(NOAA_API_URL_HILO)
    data_graph = resp_graph.json()
    data_hilo = resp_hilo.json()

    # Create the graph points list and populate it
    points = []
    x = 0
    for height_at_time in data_graph["predictions"]:
        points.append((x, float(height_at_time["v"])))
        x = x + 1
    
    # Initialize the hilo lines and times lists separately because they are displayed in different columns.  
    hilo_lines = []
    hilo_times = []
    print(data_hilo)
    
    # Make the hilo colors different based on low or hi
    for hilo in data_hilo["predictions"]:
        if hilo["type"] == "L":
            type_color = "#ccc"
        
        if hilo["type"] == "H":
            type_color = "#0c0"
        hilo_times.append(render.Text(font = "tom-thumb", color = type_color, content = str(hilo["t"])[11:16]))
        hilo_lines.append(render.Text(font = "tom-thumb", color = type_color, content = str(hilo["v"])))
    
    # Use render.Stack to put the graph in the background and then render the hilo data in two columns for alignment.  I've hard coded a station name for now.
    return render.Root(
        render.Stack(
            children = [
                render.Plot(
                    data = points,
                    width = 64,
                    height = 32,
                    color = '#00c',
                    color_inverted = '#505',
                    fill = True
                ),
                render.Box(
                    child = render.Column(
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Text(content = "Budd Bay Olympia", color = "#9ee", font = "tom-thumb"),
                            render.Row( 
                                expanded=True,
                                main_align="space_evenly",
                                children = [
                                    render.Column(
                                        children = hilo_times,
                                        cross_align = "start"
                                    ),
                                    render.Column(            
                                        children = hilo_lines,
                                        cross_align = "end"
                                    )
                                ]
                            )
                        ]
                    )
                )
            ]
        )
    )
