# Bad style:
const ReturnTypes = Union{Nothing, String, Int32, Int64, Float64}

function fetch_name(url::String)::ReturnTypes
    connection = make_connection(url)
    # This might time out and return nothing
    # ...
    data = get_data(connection)
    return data
end

# Good style:
const MaybeString = Union{Nothing, String}

function fetch_name(url::String)::MaybeString
    connection = make_connection(url)
    # This might time out and return nothing
    # ...
    name = get_name(connection)
    return name
end
