require("dotenv").config();
const functions = require("firebase-functions");
const fetch = require("node-fetch");
const cheerio = require("cheerio");

// Upgrade Realtor photo links to HD
function toHd(url) {
  if (typeof url !== "string") return url;
  return url.replace("s.jpg", "l.jpg");
}


// GET LISTINGS (HOME SCREEN)

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
          postal_code: "90004", // Default home feed
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


// SEARCH PROPERTIES (CITY OPTIONAL — FIXED)

exports.searchProperties = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "*");

  const apiKey = process.env.REALTY_API_KEY;

  const city = req.query.city?.trim() || "";
  const state = req.query.state?.trim() || "";
  const maxPrice = req.query.maxPrice ? Number(req.query.maxPrice) : undefined;
  const type = req.query.type || ""; // Home type filter (mapped from Flutter)

  try {
    let body = {
      limit: 50,
      offset: 0,
      status: ["for_sale", "ready_to_build"],
      sort: { direction: "desc", field: "list_date" },
    };

    // 🔥 If user searched with CITY
    if (city !== "") {
      body.city = city;
      if (state !== "") body.state_code = state;
    } else {
      // 🔥 If NO city → search entire state
      if (!state) {
        return res.status(400).json({
          error: "State is required when city is empty",
        });
      }
      body.state_code = state;
    }

    // Max Price
    if (maxPrice) body.price_max = maxPrice;

    // Property type filter
    if (type) body.home_type = [type];

    // Make request
    const response = await fetch(
      "https://realty-in-us.p.rapidapi.com/properties/v3/list",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-rapidapi-key": apiKey,
          "x-rapidapi-host": "realty-in-us.p.rapidapi.com",
        },
        body: JSON.stringify(body),
      }
    );

    const data = await response.json();
    return res.status(200).send(data);
  } catch (err) {
    return res.status(500).send({ error: err.toString() });
  }
});


// PROPERTY PHOTOS

exports.getPropertyPhotos = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "*");

  const apiKey = process.env.REALTY_API_KEY;

  const propertyId = req.query.property_id;
  const listingUrl = req.query.url;

  if (!propertyId && !listingUrl) {
    return res
      .status(400)
      .send({ error: "property_id or url is required" });
  }

  try {
    let urls = [];

    // API method
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
        .map((p) => p?.href)
        .filter((u) => !!u)
        .map((u) => toHd(u));
    }

    // Fallback scraper
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
      } catch (_) {}
    }

    res.status(200).send({ photos: urls || [] });
  } catch (err) {
    res.status(500).send({ error: err.toString() });
  }
});


// Deprecated Details Endpoint

exports.getPropertyDetails = functions.https.onRequest((req, res) => {
  res.status(200).send({
    message: "Deprecated. Use getPropertyPhotos instead.",
  });
});