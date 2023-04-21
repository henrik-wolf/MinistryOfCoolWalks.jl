using MinistryOfCoolWalks
using Documenter

DocMeta.setdocmeta!(MinistryOfCoolWalks, :DocTestSetup, :(using MinistryOfCoolWalks); recursive=true)

makedocs(;
    modules=[MinistryOfCoolWalks],
    authors="Henrik Wolf <henrik-wolf@freenet.de> and contributors",
    repo="https://github.com/SuperGrobi/MinistryOfCoolWalks.jl/blob/{commit}{path}#{line}",
    sitename="MinistryOfCoolWalks.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://SuperGrobi.github.io/MinistryOfCoolWalks.jl",
        edit_link="main",
        assets=String[]
    ),
    pages=[
        "Home" => "index.md",
        "Centerline correction" => "CenterlineCorrection.md",
        "Shadow intersections" => "ShadowIntersection.md",
        "Routing" => "Routing.md",
        "Hexagonal Binning" => "HexagonalBins.md"
    ]
)

deploydocs(;
    repo="github.com/SuperGrobi/MinistryOfCoolWalks.jl",
    devbranch="main"
)
