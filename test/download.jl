using RasterDataSources, Sockets, Test, URIs

@testset "interrupted downloads resume" begin
    body = rand(UInt8, 100_000)
    server = listen(Sockets.localhost, 0)
    port = Int(getsockname(server)[2])
    # Cut the first response short, then serve the requested range
    @async for n in 1:2
        sock = accept(server)
        m = match(r"(?i)range: bytes=(\d+)-", String(readuntil(sock, "\r\n\r\n")))
        start = m === nothing ? 0 : parse(Int, m[1])
        write(sock, "HTTP/1.1 $(n == 1 ? "200 OK" : "206 Partial Content")\r\n",
            "Content-Length: $(length(body) - start)\r\nConnection: close\r\n\r\n")
        write(sock, body[start+1:(n == 1 ? 30_000 : end)])
        close(sock)
    end
    path = joinpath(mktempdir(), "file.bin")
    RasterDataSources._maybe_download(URI("http://127.0.0.1:$port/f"), path)
    close(server)
    @test read(path) == body
    @test !isfile(path * ".part")
end
