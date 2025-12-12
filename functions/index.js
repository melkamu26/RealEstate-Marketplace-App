require("dotenv").config();
const admin = require("firebase-admin");
const fetch = require("node-fetch");
const cheerio = require("cheerio");

const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onRequest } = require("firebase-functions/v2/https");

admin.initializeApp();


// =============================
// TOUR STATUS PUSH NOTIFICATION
// =============================

exports.sendTourNotification = onDocumentUpdated(
  "tour_requests/{id}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    if (!before || !after) return;
    if (before.status === after.status) return;
    if (!after.buyerId) return;

    const userSnap = await admin
      .firestore()
      .collection("users")
      .doc(after.buyerId)
      .get();

    if (!userSnap.exists) return;

    const token = userSnap.data().fcmToken;
    if (!token) return;

    await admin.messaging().sendToDevice(token, {
      notification: {
        title: "Tour Update",
        body: `Your tour request was ${after.status}`,
      },
      data: {
        tourId: event.params.id,
        status: after.status,
      },
    });
  }
);


// =============================
// HELPER
// =============================

function toHd(url) {
  if (typeof url !== "string") return url;
  return url.replace("s.jpg", "l.jpg");
}


// =============================
// HOME LISTINGS
// =============================

exports.getListings = onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");

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


// =============================
// SEARCH PROPERTIES
// =============================

exports.searchProperties = onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");

  const apiKey = process.env.REALTY_API_KEY;

  const city = req.query.city?.trim() || "";
  const state = req.query.state?.trim() || "";
  const maxPrice = req.query.maxPrice ? Number(req.query.maxPrice) : undefined;
  const type = req.query.type || "";

  try {
    let body = {
      limit: 50,
      offset: 0,
      status: ["for_sale", "ready_to_build"],
      sort: { direction: "desc", field: "list_date" },
    };

    if (city) {
      body.city = city;
      if (state) body.state_code = state;
    } else {
      if (!state) {
        return res.status(400).json({
          error: "State is required when city is empty",
        });
      }
      body.state_code = state;
    }

    if (maxPrice) body.price_max = maxPrice;
    if (type) body.home_type = [type];

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
    res.status(200).send(data);
  } catch (err) {
    res.status(500).send({ error: err.toString() });
  }
});


// =============================
// PROPERTY PHOTOS
// =============================

exports.getPropertyPhotos = onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");

  const apiKey = process.env.REALTY_API_KEY;
  const propertyId = req.query.property_id;
  const listingUrl = req.query.url;

  if (!propertyId && !listingUrl) {
    return res.status(400).send({
      error: "property_id or url is required",
    });
  }

  try {
    let urls = [];

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

      urls = photos.map(p => toHd(p?.href)).filter(Boolean);
    }

    if (urls.length === 0 && listingUrl) {
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
    }

    res.status(200).send({ photos: urls });
  } catch (err) {
    res.status(500).send({ error: err.toString() });
  }
});