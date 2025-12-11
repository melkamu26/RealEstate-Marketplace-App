require("dotenv").config();
const functions = require("firebase-functions");
const fetch = require("node-fetch");
const cheerio = require("cheerio");

// Helper to upgrade photo quality to HD
function toHd(url) {
  if (typeof url !== "string") return url;
  return url.replace("s.jpg", "l.jpg");
}

// MAIN LISTINGS
exports.getListings = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "*");

  const apiKey = process.env.REALTY_API_KEY;

  try {
    const response = await fetch(
      "https://realty-in-us.p.rapidapi.com/properties/v3/list",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-rapidapi-key": apiKey,
          "x-rapidapi-host": "realty-in-us.p.rapidapi.com",
        },
        body: JSON.stringify({
          limit: 50,
          offset: 0,
          postal_code: "90004",
          status: ["for_sale", "ready_to_build"],
          sort: { direction: "desc", field: "list_date" },
        }),
      }
    );

    const data = await response.json();
    res.status(200).send(data);
  } catch (err) {
    res.status(500).send({ error: err.toString() });
  }
});

// SEARCH PROPERTIES
exports.searchProperties = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "*");

  const apiKey = process.env.REALTY_API_KEY;
  const { city, maxPrice } = req.query;

  try {
    const response = await fetch(
      "https://realty-in-us.p.rapidapi.com/properties/v3/list",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-rapidapi-key": apiKey,
          "x-rapidapi-host": "realty-in-us.p.rapidapi.com",
        },
        body: JSON.stringify({
          limit: 50,
          offset: 0,
          city: city,
          price_max: maxPrice ? Number(maxPrice) : undefined,
        }),
      }
    );

    const data = await response.json();
    res.status(200).send(data);
  } catch (err) {
    res.status(500).send({ error: err.toString() });
  }
});

// PROPERTY GALLERY
exports.getPropertyPhotos = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "*");

  const apiKey = process.env.REALTY_API_KEY;
  const propertyId = req.query.property_id;
  const listingUrl = req.query.url; // realtor public href

  if (!propertyId && !listingUrl) {
    return res.status(400).send({
      error: "property_id or url is required",
    });
  }

  try {
    let urls = [];

    // First attempt: RapidAPI detail endpoint
    if (propertyId) {
      const response = await fetch(
        `https://realty-in-us.p.rapidapi.com/properties/v3/detail?property_id=${propertyId}`,
        {
          method: "GET",
          headers: {
            "x-rapidapi-key": apiKey,
            "x-rapidapi-host": "realty-in-us.p.rapidapi.com",
          },
        }
      );

      const data = await response.json();
      const photos = data?.data?.home?.photos ?? [];

      urls = photos
        .map((p) => p && p.href)
        .filter((u) => !!u)
        .map((u) => toHd(u));
    }

    // Fallback: scrape public Realtor listing if no API photos
    if ((!urls || urls.length === 0) && listingUrl) {
      try {
        const pageRes = await fetch(listingUrl);
        const html = await pageRes.text();
        const $ = cheerio.load(html);

        const scraped = new Set();

        $("img").each((_, el) => {
          const src = $(el).attr("src") || "";
          if (src.includes("ap.rdcpix.com")) {
            scraped.add(toHd(src));
          }
        });

        urls = Array.from(scraped);
      } catch (scrapeErr) {
        // Fallback failed, keep urls as they are
      }
    }

    res.status(200).send({ photos: urls || [] });
  } catch (e) {
    res.status(500).send({ error: e.toString() });
  }
});

// PROPERTY DETAILS (deprecated)
exports.getPropertyDetails = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "*");

  res
    .status(200)
    .send({ message: "Deprecated. Use getPropertyPhotos instead." });
});